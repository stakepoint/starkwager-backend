import {
  BadRequestException,
  CanActivate,
  ConflictException,
  ExecutionContext,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Request } from 'express';
import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { WagerService } from 'src/wager/services/wager.service';
import { UsersService } from 'src/users/users.service';
import { CreateWagerInvitationDto } from '../dtos/wagerInvitations.dto';

@Injectable()
export class CreateInvitationGuard implements CanActivate {
  constructor(
    private readonly wagerService: WagerService,
    private readonly userService: UsersService,
  ) {}

  async canActivate(context: ExecutionContext) {
    const req: Request = context.switchToHttp().getRequest();
    const invitedById = req['user'].sub;

    // Convert the raw body to an instance of CreateWagerDto
    const dto = plainToInstance(CreateWagerInvitationDto, req.body);

    // Validate the DTO
    const errors = await validate(dto);
    if (errors.length > 0) {
      const formattedErrors = this.formatValidationErrors(errors);
      throw new BadRequestException(formattedErrors);
    }

    // Validate wager exists
    const wager = await this.wagerService.findOneById(dto.wagerId);
    if (!wager) {
      throw new NotFoundException('Wager not found');
    }

    // Validate invited user exists
    const invitedUser = await this.userService.findOneByUsername(
      dto.invitedUsername,
    );

    if (!invitedUser) {
      throw new NotFoundException('Invited user not found');
    }

    // Ensure user is not inviting themselves
    if (invitedUser.id === invitedById) {
      throw new ConflictException('You cannot invite yourself');
    }

    // Attach the validated DTO to the request for later use
    req.body = dto;

    return true;
  }
  private formatValidationErrors(errors: any[]) {
    const messages = errors.flatMap((error) => {
      return Object.values(error.constraints);
    });

    return {
      message: messages,
      error: 'Bad Request',
      statusCode: 400,
    };
  }
}
