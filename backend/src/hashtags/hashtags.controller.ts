import { Controller, Post, Get, Body, UseGuards } from '@nestjs/common';
import { HashtagsService } from './hashtags.service';
import { RolesGuard } from '../common/guards/roles.guard'; // Use existing RolesGuard
import { Roles } from '../common/decorators/roles.decorator'; // Apply role-based access
import { Role } from '../common/enums/roles.enum'; // Ensure correct role names
import { CreateHashtagDto } from './dto/create-hashtag.dto';

@Controller('hashtags')
@UseGuards(RolesGuard) // Apply role guard globally in this controller
export class HashtagsController {
  constructor(private readonly hashtagsService: HashtagsService) {}

  @Post()
  @Roles(Role.Admin)
  async create(@Body() createHashtagDto: CreateHashtagDto) {
    const hashtag = await this.hashtagsService.create(createHashtagDto.name);
    return { message: 'Hashtag created successfully', data: hashtag };
  }

  @Get()
  async findAll() {
    return this.hashtagsService.findAll();
  }
}
