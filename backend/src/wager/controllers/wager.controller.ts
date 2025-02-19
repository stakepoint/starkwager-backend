import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Req,
  Query,
} from '@nestjs/common';
import { WagerService } from '../services/wager.service';
import { CreateWagerDto, GetWagersQueryDto } from '../dtos/wager.dto';
import { CreateWagerGuard } from '../guards/wager.guard';
import { ApiBearerAuth, ApiQuery } from '@nestjs/swagger';

@ApiBearerAuth('JWT-AUTH')
@Controller('wager')
export class WagerController {
  constructor(private readonly wagerService: WagerService) {}

  @Post('create')
  @UseGuards(CreateWagerGuard)
  create(@Body() data: CreateWagerDto, @Req() req: Request) {
    const userId = req['user'].sub;
    return this.wagerService.createWager({ ...data, createdById: userId });
  }

  @ApiQuery({
    name: 'status',
    required: true,
    enum: ['pending', 'completed', 'active'],
  })
  @Get('all')
  findAll(@Query() query: GetWagersQueryDto) {
    return this.wagerService.getAllWagers(query.status);
  }

  @Get('view/:id')
  findOne(@Param('id') id: string) {
    return this.wagerService.findOneById(id);
  }
}
